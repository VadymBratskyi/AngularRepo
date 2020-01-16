import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { Hero } from '../_modules/Hero';
import { MessagesService } from './messages.service';

export const HEROES: Hero[] = [
  { id: 11, name: 'Dr Nice' },
  { id: 12, name: 'Narco' },
  { id: 13, name: 'Bombasto' },
  { id: 14, name: 'Celeritas' },
  { id: 15, name: 'Magneta' },
  { id: 16, name: 'RubberMan' },
  { id: 17, name: 'Dynama' },
  { id: 18, name: 'Dr IQ' },
  { id: 19, name: 'Magma' },
  { id: 20, name: 'Tornado' }
];


@Injectable({
  providedIn: 'root'
})
export class HeroesService {

  private heroesDbUrl = 'api/heroes';  // URL to web api

  httpOptions = {
    headers: new HttpHeaders({ 'Content-Type': 'application/json' })
  };

  constructor(
    private http: HttpClient,
    private messageServ: MessagesService
  ) { }

  getHeroes() : Observable<Hero[]>{
    this.messageServ.add('HeroService: fetched heroes');
    return of(HEROES);
  }

  searchHeroes(term: string): Observable<Hero[]> {
    if (!term.trim()) {
      // if not search term, return empty hero array.
      return this.getHeroesFromDb();
    }
    return this.http.get<Hero[]>(`${this.heroesDbUrl}/?name=${term}`).pipe(
      tap(_ => console.log(`found heroes matching "${term}"`)),
      catchError(this.handleError<Hero[]>('searchHeroes', []))
    );
  }

  getHeroesFromDb (): Observable<Hero[]> {
    this.messageServ.add('HeroService: fetched heroes from Db');
    return this.http.get<Hero[]>(this.heroesDbUrl)
    .pipe(
      tap(_ => console.log('fetched heroes')),
      catchError(this.handleError<Hero[]>('getHeroes', []))
    );
  }

  getHeroesByIdFromDb (id: number): Observable<Hero[]> {

    const url = `${this.heroesDbUrl}/${id}`;
    this.messageServ.add('HeroService: fetched heroes by Id from Db');

    return this.http.get<Hero>(url)
    .pipe(
      map(h => [h]),
      tap(_ => console.log(`fetched hero id=${id}`)),
      catchError(this.handleError<Hero[]>(`getHero id=${id}`))
      );
  }

  addHero (hero: Hero): Observable<Hero> {
    return this.http.post<Hero>(this.heroesDbUrl, hero, this.httpOptions)
    .pipe(
      tap((newHero: Hero) => console.log(`added hero w/ id=${newHero.id}`)),
      catchError(this.handleError<Hero>('addHero'))
    );
  }

  updateHero(hero: Hero): Observable<Hero> {
    return this.http.put(this.heroesDbUrl, hero, this.httpOptions)
    .pipe(
      tap(_ => console.log(`updated hero id=${hero.id}`)),
      catchError(this.handleError<any>('updateHero'))
    );
  }

  deleteHero(hero: Hero | number): Observable<Hero>  {
    
    const id = typeof hero === 'number' ? hero : hero.id;
    const url = `${this.heroesDbUrl}/${id}`;
  
    return this.http.delete<Hero>(url, this.httpOptions).pipe(
      tap(_ => console.log(`deleted hero id=${id}`)),
      catchError(this.handleError<Hero>('deleteHero'))
    );
  }

  private handleError<T> (operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
  
      // TODO: send the error to remote logging infrastructure
      console.error(error); // log to console instead
  
      // TODO: better job of transforming error for user consumption
      console.error(`${operation} failed: ${error.message}`);
  
      // Let the app keep running by returning an empty result.
      return of(result as T);
    };
  }

}
